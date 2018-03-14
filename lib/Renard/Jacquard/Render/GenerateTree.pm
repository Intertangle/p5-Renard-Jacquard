use Renard::Incunabula::Common::Setup;
package Renard::Jacquard::Render::GenerateTree;
# ABSTRACT: Walk the scene graph and generate tree

use Moo;
use Renard::Jacquard::Render::State;
use Path::Tiny;
use Renard::Jacquard::Layout::All;
use Renard::Jacquard::Layout::Composed;
use Tree::DAG_Node;

=method get_render_tree

Returns a L<Tree::DAG_Node> of renderable objects.

=cut
method get_render_tree(
	:$root,
	:$state = Renard::Jacquard::Render::State->new,
	) {

	my $tree = Tree::DAG_Node->new;

	if( ref $root->content ne 'Renard::Jacquard::Content::Null' ) {
		my $taffeta = $root->content->as_taffeta(
			state => $state,
		);

		$tree->attributes({
			render => $taffeta,
		});
	} else {
		my $layout;
		my $states;
		#if( ref $root->layout ne 'Renard::Jacquard::Layout::Composed' ) {
			$states = $root->layout->update( state => $state );
		#} else {
			#$states = $root->layout->update;
		#}
		my $children = $root->children;

		for my $child (@$children) {
			my $new_state = $states->get_state( $child );
			$tree->add_daughter(
				$self->get_render_tree(
					root     => $child,
					state    => $new_state,
				)
			);
		}
	}
	$tree->attributes->{bounds} = $root->bounds( $state );
	$tree->attributes->{state} =  $state;

	$tree;
}

=method render_tree_to_svg

Renders the result of C<get_render_tree> to an SVG file.

=cut
method render_tree_to_svg( $render_tree, $path ) {
	require SVG;
	my $svg = SVG->new;

	fun walker( $node, $svg ) {
		my @daughters = $node->daughters;
		if( exists $node->attributes->{render} ) {
			my $el = $node->attributes->{render}->render_svg( $svg );
		}
		my $group = @daughters > 1 ? $svg->group : $svg ;
		for my $daughter (@daughters) {
			walker( $daughter, $group );
		}
	};

	walker( $render_tree, $svg->group );

	path($path)->spew_utf8($svg->xmlify);
}

1;